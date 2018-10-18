# ----------------------------------------------------------------------------
# Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
# Amstrad CPC.
# ----------------------------------------------------------------------------

LANGCODES="es en"

for langc in $LANGCODES; do
	ucaselang=`echo $langc | tr [a-z] [A-Z]`
	langmac=LANG_$ucaselang 
	make GAMELANG=$langc GAMELANG_MAC=$langmac -f $1 $2
done
