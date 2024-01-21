import mysql.connector
import serial
from pyswip import Prolog

mydb = mysql.connector.connect(
    host="localhost",
    user="root",
    password="261041890",
    database="casas_db"
)

ser = serial.Serial('COM3', 9600)

prolog = Prolog()
prolog.consult('casas.pl')

while True:
  # Read the incoming data
  data = ser.readline().decode('utf-8').strip()

  # Parse the incoming data
  distance1, distance2, distance3 = data.split(',')

  # Save the data into the MySQL database
  mycursor = mydb.cursor()
  sql = "INSERT INTO logs (id_sensor, distancia, fecha, pir_state) VALUES (%s, %s, NOW(), 1)"
  val = (1, distance1)
  mycursor.execute(sql, val)
  val = (2, distance2)
  mycursor.execute(sql, val)
  val = (3, distance3)
  mycursor.execute(sql, val)
  mydb.commit()
  
  # Call your Prolog rule
  results = list(prolog.query('generar_hechos'))

  # Call your Prolog rule
  results2 = list(prolog.query('alerta_recursiva(Alerta)'))
  
  mycursor.execute("SET SQL_SAFE_UPDATES = 0;")

  mycursor.execute("DELETE FROM casas_db.logs;")
  mydb.commit()