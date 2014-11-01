import sys

input_file = open(sys.argv[1], 'r')
mysql_file = open(sys.argv[2], 'r')

score_base = dict()
for line in mysql_file:
    split = line.strip().split(' ')
    score_base[split[0]] = int(split[1])

index = -1
key = ''
for line in input_file:
    index += 1
    split = line.strip().split('\\s+')
    val = split[-1]
    if index % 2 == 0:
        key = val
    else: 
        value = float(val) - (score_base[key] / 60000) + (score_base[key] / (12 * 60 * 60000))
        print 'ZADD ir %d %s\r' % (value, key)

