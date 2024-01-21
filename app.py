import mysql.connector
from mysql.connector import Error
from telegram import Update
from telegram.ext import Updater, CommandHandler, MessageHandler, Filters, CallbackContext
import schedule
import time

# Token de tu bot proporcionado por BotFather
TOKEN = "6833534632:AAG2QJ5-v0RTRlJeRIrQOmlvsSRrdjGBAQE"

# Configuración de la base de datos MySQL
DB_HOST = "localhost"
DB_USER = "root"
DB_PASSWORD = "261041890"
DB_NAME = "casas_db"

# Función para manejar el comando /start
def start(update: Update, context: CallbackContext) -> None:
    update.message.reply_text("¡Hola! Soy un bot que puede recibir mensajes de 'casa vacía ###' o 'casa habitada ###' mas el numero de casa '123'.")

# Función para manejar los mensajes de texto
def handle_status_message(update: Update, context: CallbackContext) -> None:
    message_text = update.message.text.lower()

    palabras = message_text.split()


    if len(palabras) == 1 and palabras[0] == 'status':
        alerts = []
        try:
            # Conecta a la base de datos MySQL
            connection = mysql.connector.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_NAME
            )

            # Crea un cursor para interactuar con la base de datos
            cursor = connection.cursor()

            # Consulta la tabla 'alertas'
            cursor.execute("SELECT * FROM alertas")
            alerts = cursor.fetchall()
            for alert in alerts:
                update.message.reply_text(alert)
        except Error as e:
            print("Error al conectarse a la base de datos:", e)
        return
    elif len(palabras) < 3 or palabras[0] not in ['casa', 'habitada'] or palabras[1] not in ['vacía', 'habitada']:
        update.message.reply_text("Formato incorrecto. Utiliza 'casa vacía <numero>' o 'casa habitada <numero>'.")
        return
    else:
        try:
            numero_de_casa = int(palabras[2])
        except ValueError:
            update.message.reply_text("No se proporcionó un número de casa válido.")
            return

        if palabras[1] == 'vacía':
            update.message.reply_text(f"Se ha registrado que la casa {numero_de_casa} está vacía.")
            update_database(0, numero_de_casa)
        else:
            update.message.reply_text(f"Se ha registrado que la casa {numero_de_casa} está habitada.")
            update_database(1, numero_de_casa)

# Función para actualizar la base de datos MySQL
def update_database(is_empty: int, numero_de_casa: int) -> None:
    try:
        # Conecta a la base de datos MySQL
        connection = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )

        # Crea un cursor para interactuar con la base de datos
        cursor = connection.cursor()

        # Verifica si ya existe un registro para el número de casa
        cursor.execute("SELECT * FROM casas WHERE idcasas = %s", (numero_de_casa,))
        existing_record = cursor.fetchone()

        if existing_record:
            # Si ya existe un registro, actualiza su estado
            cursor.execute("UPDATE casas SET statusUSO = %s WHERE idcasas = %s", (is_empty, numero_de_casa))
            print(f"DEBUG: Se ha actualizado el estado de la casa {numero_de_casa}.")
        else:
            # Si no existe un registro, crea uno nuevo
            cursor.execute("INSERT INTO casas (idcasas, statusUSO) VALUES (%s, %s)", (numero_de_casa, is_empty))
            print(f"DEBUG: Se ha registrado una nueva casa: {numero_de_casa} {'vacía' if is_empty else 'habitada'}.")

        # Guarda los cambios
        connection.commit()

    except Error as e:
        print("Error al conectarse a la base de datos:", e)

    finally:
        # Cierra la conexión
        if connection.is_connected():
            cursor.close()
            connection.close()

def main() -> None:
    # Crea el objeto Updater y pasa el token de tu bot
    updater = Updater( TOKEN)

    # Obtiene el despachador para registrar manejadores
    dispatcher = updater.dispatcher

    # Registra manejadores para comandos y mensajes de texto
    dispatcher.add_handler(CommandHandler("start", start))
    dispatcher.add_handler(MessageHandler(Filters.text & ~Filters.command, handle_status_message))

    # Inicia el bot
    updater.start_polling()

    # Detiene el bot en caso de interrupción
    updater.idle()

if __name__ == '__main__':
    main()