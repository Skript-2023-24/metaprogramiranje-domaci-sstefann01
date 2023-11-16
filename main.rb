# frozen_string_literal: true

require_relative 'domaci_1'

t = get_table('1yOnHnXrwZcf-K27EphP4IEZSc1HbtG0t4k6a4AUOEuY')
t2 = get_table('1yOnHnXrwZcf-K27EphP4IEZSc1HbtG0t4k6a4AUOEuY')

p 'stavka 1'
matrix = t.to_matrix
p matrix

p 'stavka 2'
p t.row(1)

p 'stavka 3'
t.each do |col|
  col.each { |val| p val }
end

p 'stavka 5'
p t['Prva Kolona']
p t['Prva Kolona'][1]
t['Prva Kolona'][1] = 2556
p t['Prva Kolona'][1]

p 'stavka 6'
p t.prvaKolona[1]
p t.drugaKolona.sum
p t.trecaKolona.avg
p t.index.rn12721
# p t.prvaKolona.map { |cell| cell.to_s << " dodatak"}

p 'stavka 7 i 10'
t.print_table

p 'stavka 8'
p (t + t2).print_table


p 'stavka 9'
p (t - t2).print_table

