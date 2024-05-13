import unittest
from unittest import mock
from lambda_function import lambda_handler
import os
import decimal

class TestLambdaHandler(unittest.TestCase):

    @mock.patch.dict(os.environ, {"AWS_ACCESS_KEY_ID": "test_key", "AWS_SECRET_ACCESS_KEY": "test_secret"})
    @mock.patch('function.boto3')
    def test_lambda_handler(self, mock_boto3):
        # Mock DynamoDB resource and update_item method
        mock_table = mock.Mock()
        mock_table.update_item.return_value = {'Attributes': {'visitors': decimal('2')}}
        mock_boto3.resource.return_value.Table.return_value = mock_table

        # Invoke the lambda_handler
        event = {}
        context = {}
        response = lambda_handler(event, context)

        # Assert status code is 200
        self.assertEqual(response['statusCode'], 200)

        # Assert visitor count has been incremented
        self.assertEqual(response['body'], '{"visitor_count": 2}')

        # Assert CORS headers are present
        self.assertIn('Access-Control-Allow-Headers', response['headers'])
        self.assertIn('Access-Control-Allow-Origin', response['headers'])
        self.assertIn('Access-Control-Allow-Methods', response['headers'])

        # Assert AWS credentials are present
        self.assertIn('AWS_ACCESS_KEY_ID', os.environ)
        self.assertIn('AWS_SECRET_ACCESS_KEY', os.environ)

if __name__ == '__main__':
    unittest.main()
