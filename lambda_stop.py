import boto3
import os
import json
from datetime import datetime

ec2_client = boto3.client('ec2')

def handler(event, context):
    instance_id = os.environ['INSTANCE_ID']
    
    try:
        print(f"Stopping EC2 instance: {instance_id}")
        print(f"Triggered at: {datetime.now().isoformat()}")
        
        response = ec2_client.stop_instances(InstanceIds=[instance_id])
        
        result = {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Instance {instance_id} stop command initiated',
                'instance_id': instance_id,
                'action': 'stop',
                'timestamp': datetime.now().isoformat(),
                'response': response['ResponseMetadata']
            })
        }
        
        print(f"Response: {result}")
        return result
        
    except Exception as e:
        error_message = f"Error stopping instance {instance_id}: {str(e)}"
        print(f"ERROR: {error_message}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_message,
                'instance_id': instance_id,
                'timestamp': datetime.now().isoformat()
            })
        }
