from websocket import create_connection
#ws = create_connection("ws://echo.websocket.events/")
ws = create_connection("ws://localhost:8080/home/ws/.ws")
print(ws.recv())
ws.send("Hello, World")
print(ws.recv())
ws.send("Hey")
print(ws.recv())
#print("Sending 'Hello, World'...")
#ws.send("Hello, World")
#print("Sent")
#print("Receiving...")
#result =  ws.recv()
#print("Received '%s'" % result)
ws.close()