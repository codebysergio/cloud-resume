import boto3
dynamodb = boto3.resource ('dynamodb',region_name='us-east-1')
table = dynamodb.Table('Web-Views')
def lambda_handler(event, context):
    response = table.get_item(
            Key = {
                'id': '1'
            })
    views = response['Item']['views']
    views = views + 1
    print(views)
    response = table.update_item(
            Key = {
            'id': '1'
            },
            UpdateExpression = 'SET #v = :val',
            ExpressionAttributeValues = {
                ':val': views
            },
            ExpressionAttributeNames = { '#v': 'views'  }
    )
    return{
            'StatusCode': 200,
            'body': views
     }