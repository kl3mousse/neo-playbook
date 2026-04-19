print(ord("─"))

special = u"\u2500"
abc = u'(-/-/─) '
x = abc.replace(special,'X')
print (x)
print(ord(abc[5:1]))