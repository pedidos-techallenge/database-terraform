import pymysql
from pymysql.constants import CLIENT
import os

def lambda_handler(event, context):
    # Retrieve environment variables
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_password = os.environ['DB_PASSWORD']
    db_name = os.environ['DB_NAME']
    
    # Connect to the MySQL RDS instance
    connection = pymysql.connect(host=db_host,
                                 user=db_user,
                                 password=db_password,
                                 database=db_name,
                                 client_flag=CLIENT.MULTI_STATEMENTS
                                 )
    
    cursor = connection.cursor()
    
    # Your SQL initialization script
    with open("./init.sql", "r") as file:
        sql_init_script = file.read()
    
    try:
        # Execute the SQL script
        cursor.execute(sql_init_script)
        connection.commit()
        return {
            'statusCode': 200,
            'body': 'SQL script executed successfully!'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f"Error executing SQL script: {str(e)}"
        }
    finally:
        cursor.close()
        connection.close()
