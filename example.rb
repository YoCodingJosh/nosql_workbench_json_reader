# frozen_string_literal: true

require_relative './helper'

dynamo = DynamoDBSingleton.instance.db

puts 'Creating table \'BouncerClient\''

table_schema = get_table_definition('BouncerClient', complete: false)
result = create_table(dynamo, table_schema)

if result == 'Error'
  puts 'Error in creating BouncerClient table'
end
