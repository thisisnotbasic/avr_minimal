SRCDIR=src
echo SRCDIR := $SRCDIR> makefile

echo cfiles=\\>>  makefile
find  $SRCDIR -name "*.c"\
  | sed "s%\.c%\.c\\\\%g" | sed '$ s/.$//'  >> makefile
# Leerzeile
echo "" >> makefile

echo sxfiles=\\>>  makefile
find  $SRCDIR -name "*.sx"\
  | sed "s%\.sx%\.sx\\\\%g" | sed '$ s/.$//'  >> makefile
# Leerzeile
echo "" >> makefile

echo include include.mak >> makefile
echo makefile created!

