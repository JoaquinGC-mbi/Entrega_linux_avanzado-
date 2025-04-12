# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2).

# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.

# STAR --runThreadN 4 --runMode genomeGenerate --genomeDir <outdir> \
# --genomeFastaFiles <genomefile> --genomeSAindexNbases 9

# Argumentos
file=$1
directory=$2

# Comprobar si existe el directorio del indexado con if [-d]
if [ -d "${directory}" ]
then
	echo "El indexado ya se ha llevado a cabo. Saltando comando"
else 
	# creacion de linea de comandos para STAR_index con los argumentos dados
	echo "Comenzando STAR index de $file ..."
	mkdir -p ${directory}
	STAR \
		--runThreadN 4 \
		--runMode genomeGenerate \
		--genomeDir ${directory}/ \
		--genomeFastaFiles ${file} \
		--genomeSAindexNbases 9
	echo "Indexado de $file completado"
fi
