import boto3
dynamodb = boto3.resource ('dynamodb',region_name='us-east-1')
table = dynamodb.Table('Web-Views')
response = table.get_item(
    Key = {
        'id': '1'
})

print(response['Item'])