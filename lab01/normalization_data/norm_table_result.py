import csv
from random import randrange

#def normalize_row(row):

with open('formula_1_dataset/results.csv', 'r', encoding='ISO-8859-1') as rf, open('result_norm.csv', 'w') as wf:
    reader = csv.reader(rf)
    writer = csv.writer(wf)
    #next(reader) 
    len = 0

    for row in reader:
        row.pop(11)
        row.pop(14)

        if (len == 0):
            writer.writerow(row) 
        else:
            #normalize_row(row)
            writer.writerow(row) 

        len += 1

print('Number of rows in table -', len)
