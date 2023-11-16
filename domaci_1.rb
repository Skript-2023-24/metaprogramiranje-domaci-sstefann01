# frozen_string_literal: true

require 'google_drive'

class Column
  include Enumerable
  attr_accessor :values, :session, :worksheet, :table

  def initialize(values, session, worksheet)
    @values = values
    @session = session
    @worksheet = worksheet
    @table
  end

  def method_missing(method_name, *arguments, &block)
    cell_index = @values.find_index { |val| val.downcase.gsub(' ', '') == method_name.to_s.downcase.gsub(' ', '') }
    cell_index.nil? ? super : @table.row(cell_index)
  end

  def respond_to_missing?(method_name, include_private = true)
    cell = method_name.to_s.downcase.gsub(' ', '')
    @values.any? { |val| val.downcase.gsub(' ', '') == cell } || super
  end

  def each(&block)
    @values.each(&block)
  end

  def [](index)
    @values[index]
  end

  def []=(index, new_value)
    @values[index] = new_value
    @worksheet[index, @worksheet.rows[0].index(@values.first)] = new_value
    @worksheet.save
    @worksheet.reload
  end

  def numeric?(value)
    value.match?(/\A-?\d+(\.\d+)?\Z/)
  end

  def sum
    numeric_values = @values[1..].select { |value| numeric?(value) }
    numeric_values.sum(&:to_f)
  end

  def avg
    sum.to_f / (@values.size - 1)
  end

end

class Table
  include Enumerable
  attr_accessor :table, :session, :worksheet

  def initialize(values, session, worksheet)
    @table = values
    @session = session
    @worksheet = worksheet

    @table.each { |col| col.table = self }
  end

  def is_row_empty?(row_index)
    @table.all? { |column| column.values[row_index].to_s.strip.empty? }
  end

  def method_missing(method_name)
    column = @table.find { |col| col.first.to_s.downcase.gsub(' ', '') == method_name.to_s.downcase.gsub(' ', '')}
    column || super
  end

  def respond_to_missing?(method_name, include_private = true)
    exists = @table.any? { |col| col.first.downcase.gsub(' ', '') == method_name.to_s.downcase.gsub(' ', '')}
    exists || super
  end

  def each(&block)
    @table.each(&block)
  end

  def [](column_name)
    column_name = column_name.downcase
    target_column = @table.find { |col| col.first.downcase == column_name }

    if target_column.nil?
      puts "Error: Column '#{column_name}' not found."
      nil
    else
      target_column.values
    end
  end

  def total_or_subtotal?(row_index)
    @table.any? do |column|
      cell_value = column.values[row_index].to_s.downcase
      cell_value.include?('total') || cell_value.include?('subtotal')
    end
  end

  def print_table
    column_widths = @table.map do |column|
      column.values.map { |value| value.to_s.length }.max
    end

    @table.first.values.size.times do |row_index|
      next if is_row_empty?(row_index)
      next if total_or_subtotal?(row_index)

      @table.each_with_index do |column, col_index|
        print column.values[row_index].to_s.ljust(column_widths[col_index] + 2)
      end
      puts
    end
  end

  def +(other)
    unless headers_match?(other)
      puts 'Tables cannot be added, the headers are different'
      return nil
    end

    i = 0
    columns = @table

    columns.each do |col|
      col.values += other.table[i].values[1..]
      i += 1
    end

    Table.new(columns, @session, @worksheet)
  end

  def headers_match?(other_table)
    header = @table.map(&:first)
    other_header = other_table.table.map(&:first)
    header == other_header
  end

  def -(other)
    unless headers_match?(other)
      puts 'Tables cannot be added, the headers are different'
      return nil
    end

    i = 0
    columns = @table

    columns.each do |col|
      col.values -= other.table[i].values[1..]
      i += 1
    end

    Table.new(columns, @session, @worksheet)
  end

  def row(row_index)
    @table.map { |col| col[row_index] }
  end

  def to_matrix
    # @worksheet.rows
    matrix = []
    row_count = @table.first.values.size
    row_count.times do |row_index|
      row = @table.map { |column| column.values[row_index] }
      matrix << row
    end
    matrix
  end

end

def get_table(table_id)
  session = GoogleDrive::Session.from_config('config.json')
  worksheet = session.spreadsheet_by_key(table_id).worksheets[0]

  column_values = []
  table_values = []

  (1..worksheet.num_cols).each do |col|
    (1..worksheet.num_rows).each do |row|
      column_values << worksheet[row, col]
    end
    table_values << Column.new(column_values, session, worksheet)
    column_values = []
  end

  Table.new(table_values, session, worksheet)

end
