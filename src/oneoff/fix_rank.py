import sys

mysql_file = open(sys.argv[1], 'r')

for line in mysql_file:
    split = line.strip().split(' ')
    value = (int(split[1]) / (12.0 * 60 * 60000))
    print 'ZADD ir %f %s\r' % (value, split[0])

