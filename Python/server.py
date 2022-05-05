import asyncio
import argparse
import time
import sys
import logging
import aiohttp
import json
from datetime import datetime

API_key = ''

port_dict = {"Riley": 12925,
             "Jaquez": 12926,
             "Juzang": 12927,
             "Campbell": 12928,
             "Bernard": 12929}

relationships = {
    "Riley": ["Jaquez", "Juzang"],
    "Jaquez": ["Riley", "Bernard"],
    "Juzang": ["Riley", "Bernard", "Campbell"],
    "Campbell": ["Juzang", "Bernard"],
    "Bernard": ["Juzang", "Jaquez", "Campbell"]
}

class Server:
    def __init__(self, name, port, ip ='127.0.0.1', message_max_length=1e6):
        self.name = name
        self.ip = ip
        self.port = port
        self.message_max_length = int(message_max_length)
        self.client_timestamp = dict() # for flooding algorithms
        self.message_history = dict()
        
        logging.info("Starting log for server {}".format(name))

    async def fetch_input(self,reader,writer):
        while not reader.at_eof():
            data = await reader.readline()
            message = data.decode()
            # if empty message, will return it
            if message == "":
                continue
            logging.info("{} recieved: {}".format(self.name, message))

            parsed_message = await self.parse_message(message)
            sendback_message = parsed_message

            writer.write(sendback_message.encode())
            await writer.drain()

            writer.close()
        
    async def parse_message(self, message):
            parsed_msg = message.strip().split()

            if len(parsed_msg) != 4:
                if len(parsed_msg) == 6 and parsed_msg[0] == "AT":
                    server_id = parsed_msg[1]
                    client_id = parsed_msg[3]
                    # message propagated from other servers
                    logging.info("Receiving a propagated message from other servers")
                    sendback_message = None
                    if client_id in self.client_timestamp:
                        # if message from same client ID received, then entry already exists for server
                        logging.info("Client ID in {} recognized and already logged".format(client_id))
                        if float(parsed_msg[5]) > self.client_timestamp[client_id]: 
                            # update and flood
                            logging.info("Updating and flooding message for client {}".format(server_id))
                            self.client_timestamp[client_id] = float(parsed_msg[5])
                            self.message_history[client_id] = message
                            await self.flood_message(message)
                        else:
                            # message already received and no longer needs to be flooded
                            logging.info("Message for client in {} already received, no longer need to propagate.".format(server_id))
                            pass
                    else: 
                        # have not received message from this ID
                        logging.info("Logging new client data in {} and flooding message".format(server_id))
                        self.client_timestamp[client_id] = float(parsed_msg[5])
                        self.message_history[client_id] = message
                        await self.flood_message(message)
                else: 
                    sendback_message = "? {message}"
            elif parsed_msg[0] == "IAMAT":
                if self.check_iamat(parsed_msg):
                    sendback_message = await self.handle_iamat(parsed_msg)
                else:
                    sendback_message = "? {message}"
            elif parsed_msg[0] == "WHATSAT":
                if self.check_whatsat(parsed_msg):
                    sendback_message = await self.handle_whatsat(parsed_msg)
                else:
                    sendback_message = "? {message}"
            else:
                sendback_messgae = "? {message}"

            #return message to client
            if sendback_message != None:
                return sendback_message

    def time_diff(self,client_time):
        time_float= float(client_time)

        time_lapsed= time.time()-time_float
        if (time_lapsed>0):
            time_str = "+" + str(time_lapsed)
        else:
            time_str = "-" + str(time_lapsed)
        return time_str

    async def handle_iamat(self, message_info):
        client_id = message_info[1]
        coordinates = message_info[2]
        timestamp = message_info[3]

        iamat_response = f"AT {self.name} {self.time_diff(timestamp)} {client_id} {coordinates} {timestamp}"
        self.client_timestamp[client_id] = float(timestamp)
        self.message_history[client_id] = iamat_response

        await self.flood_message(iamat_response)
        return iamat_response

    async def handle_whatsat(self, message_info):
        client_id = message_info[1]
        coordinates = self.message_history[client_id].split()[4]
        radius = message_info[2]
        max_results = message_info[3]

        parsed_coordinates = self.parse_coords(coordinates)
        if parsed_coordinates == None:
            print("Incorrect coordinate format, fatal error")
            sys.exit()

        logging.info("Sending request to Google Places for coordinates: {}".format(parsed_coordinates))
            
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location={}&radius={}&key={}'.format(parsed_coordinates, radius, API_key)
        
        google_resp = await self.fetch_google_places(url, max_results)

        whatsat_resp = "{}\n{}\n\n".format(self.message_history[client_id], str(google_resp).rstrip('\n'))
        return whatsat_resp
        
    async def flood_message(self, message):
        # send message to every relationship of this server
        for servername in relationships[self.name]:
            try:
                reader, writer = await asyncio.open_connection(self.ip, port_dict[servername])
                logging.info("Connection has been opened between {} and {} sending: {}".format(self.name, servername, message))
                writer.write(message.encode())
                await writer.drain()
                logging.info("Message has been propagated and connection with {} is now closed".format(servername))
                writer.close()
                await writer.wait_closed()
            except:
                logging.info("Error: Cannot connect to server {}".format(servername))

    async def fetch_google_places(self, link, max_results):
        async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=False)) as session:
            google_json_resp = await self.fetch_google_resp(session, link)
            google_resp_max = json.loads(google_json_resp)
            logging.info("Successfully fetched {} places from Google Places".format(len(google_resp_max["results"])))
            if len(google_resp_max["results"]) <= int(max_results):
                return google_json_resp
            else:
                #make sure to only return max results asked for
                google_resp_max["results"] = google_resp_max["results"][0:int(max_results)]
                return json.dumps(google_resp_max, sort_keys=True, indent=4)

    async def fetch_google_resp(self, session, url):
        async with session.get(url) as response:
            return await response.text()

    def parse_coords(self, coordinates):
        plus = coordinates.rfind('+') #obtain the indices
        minus = coordinates.rfind('-')
        if plus > 0:
            return "{},{}".format(coordinates[:plus], coordinates[plus:])
        if minus > 0:
            return "{},{}".format(coordinates[:minus], coordinates[minus:])
        return None

    def check_iamat(self, iamat_message):
        if len(iamat_message) != 4:
            logging.info("IAMAT message incorrect length")
            return False
        try:
            coords = iamat_message[2].split('-')
            if (coords[0][0] != '+'):
                return False
            else:
                latitude = coords[0][1:]
                lat_int = float(latitude)
                longitude = coords[1]
                long_int = float(longitude)
                return True
        except:
            logging.info("IAMAT coordinates format incorrect")
            return False
        try:
            float(iamat_message[3])
            return True
        except:
            logging.info("IAMAT datetime stamp not incorrect")
            return False
        return True

    def check_whatsat(self, whatsat_message):
        if len(whatsat_message) != 4:
            logging.info("WHATSAT message length not correct")
            return False
        try:
            radius = float(whatsat_message[2])
            max_results = float(whatsat_message[3])
        except:
            logging.info("WHATSAT parameters incorrect format")
            return False
        if not (0<int(whatsat_message[2]) and 50>=int(whatsat_message[2])):
            logging.info("Radius parameter out of bounds")
            return False
        if not (0<int(whatsat_message[3]) and 20>=int(whatsat_message[3])):
            logging.info("Max items parameter out of bounds")
            return False
        if whatsat_message[1] not in self.client_timestamp:
            return False
        return True

    async def run_forever(self):
        logging.info('Starting server {} on port {}'.format(self.name, self.port))
        #Starting server
        server = await asyncio.start_server(self.fetch_input, self.ip, self.port)

        # Serve requests until Ctrl+C is pressed
        async with server:
            await server.serve_forever()

        # Closing server
        logging.info('Shutting down server {} on port {}'.format(self.name, self.port))

        server.close()

        
def main():
    parser= argparse.ArgumentParser(description='Asyncio Project')
    parser.add_argument('server_name', type=str, help='server name is required')

    args=parser.parse_args()

    if not args.server_name in port_dict:
        print("Error: Server name {} is not recognized".format(args.server_name))
        sys.exit()

    logging.basicConfig(filename="Server_{}.log".format(args.server_name), format='%(levelname)s: %(message)s', filemode='w+', level=logging.INFO)

    port_num = port_dict[args.server_name]
    
    server = Server(args.server_name, port_num)

    try:
        asyncio.run(server.run_forever())
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
