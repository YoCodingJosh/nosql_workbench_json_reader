# frozen_string_literal: true

require 'aws-sdk-dynamodb'
require 'json'
require 'ostruct'
require 'singleton'

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def get_table_definition(table_name, complete: true)
  # Extract the raw table info from the NoSQL Workbench JSON file
  oshiete_json = JSON.parse(File.read("#{__dir__}/Oshiete.json"))
  table_definitions = oshiete_json['DataModel']
  raw_table = table_definitions.detect { |table| table['TableName'] == table_name }

  # Convert it lmao
  table = OpenStruct.new
  table.table_name = raw_table['TableName']
  table.key_schema = [
    # Partition key
    {
      attribute_name: raw_table['KeyAttributes']['PartitionKey']['AttributeName'],
      key_type: 'HASH',
      attribute_type: raw_table['KeyAttributes']['PartitionKey']['AttributeType']
    }
  ]

  # Conditionally add the sort key
  unless raw_table['KeyAttributes']['SortKey'].nil?
    table.key_schema.push(
      {
        attribute_name: raw_table['KeyAttributes']['SortKey']['AttributeName'],
        key_type: 'RANGE',
        attribute_type: raw_table['KeyAttributes']['PartitionKey']['AttributeType']
      }
    )
  end

  table.attribute_definitions = []

  # Add the schema keys (so we can have their types)
  schema_key_attributes = []
  table.key_schema.each do |atr|
    schema_key_attributes.push({
                                 attribute_name: atr['attribute_name'.to_sym],
                                 attribute_type: atr['attribute_type'.to_sym]
                               })
  end

  table.attribute_definitions.push schema_key_attributes[0]

  # Remove the attribute_type field because it isn't necessary
  new_key_schema = []
  table.key_schema.each do |key|
    new_key_schema.push({
                          attribute_name: key['attribute_name'.to_sym],
                          key_type: key['key_type'.to_sym]
                        })
  end
  table.key_schema = new_key_schema

  # Add the rest of the keys
  raw_table['NonKeyAttributes'].each do |attribute|
    # We don't need non-key attributes if not complete schema (SDK won't take it)
    next unless complete

    converted_attribute = OpenStruct.new
    converted_attribute.attribute_name = attribute['AttributeName']
    converted_attribute.attribute_type = attribute['AttributeType']
    table.attribute_definitions.push converted_attribute.to_h
  end

  # Set the provisioned throughput
  table.provisioned_throughput = {
    read_capacity_units: raw_table['ProvisionedCapacitySettings']['ProvisionedThroughput']['ReadCapacityUnits'],
    write_capacity_units: raw_table['ProvisionedCapacitySettings']['ProvisionedThroughput']['WriteCapacityUnits']
  }

  # We're done!
  table.to_h
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength

def create_table(dynamodb_client, table_definition)
  response = dynamodb_client.create_table(table_definition)
  response.table_description.table_status
rescue StandardError => e
  puts "Error creating table: #{e.message}"
  'Error'
end

# Singleton wrapper for DynamoDB that makes migrations easier to follow
class DynamoDBSingleton
  include Singleton

  @db_instance = nil

  def initialize
    @db_instance = Aws::DynamoDB::Client.new
  end

  def db
    @db_instance
  end
end
