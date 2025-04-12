# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).

# Argumentos
directory=$1
output=$2
sample=$3

mkdir -p ${output}
# Comprobar si existen los archivos mediante la opcion if [-f]. Si existen, salta la ejecución mediante el comando exit 0
if [ -f ${output}/${sample}.fastq.gz ]
then 
	echo "Los archivos combinados ya existen. Saltando el comando"
	exit 0
else
	echo "Comenzando combinacion de $sample ..."
	# Utilización de zcat para combinar los archivos sin descomprimirlos, diferenciando entre los archivos .1s y 2.s. Con gzip nos aseguramos que el archivo resultante es .gz
	zcat ${directory}/${sample}*.1s_sRNA.fastq.gz ${directory}/${sample}*.2s_sRNA.fastq.gz | gzip > ${output}/${sample}.fastq.gz
	echo "Los archivos combinados estan en: $output"
fi
