echo "############ Comenzando pipeline el $(date +'%Y-%m-%d %H:%M:%S')... ##############"

# Activacion del entorno conda
# Con el comando source activamos el script activate dentro de la carpeta donde esta instalado conda
# Posteriormente, se indica que entorno activar con conda activate
source /home/vant/miniforge3/bin/activate
conda activate ejercicio_linux
echo "Entorno conda activado. Comenzando script"

# Script para eliminación de archivos en donde, al definir argumentos, se eliminan los directorios indicados
bash scripts/cleanup.sh

#Download all the files specified in data/filenames
# Antiguo bucle for empleado para descargar los archivos
#if [ -f "list_urls.txt" ]
#then 
#	echo "Comienza el programa ..."
	# Empleo del comando for mas cat para que lea cada linea del listado y le asigne la variable url
#	for url in $(cat list_urls.txt)
#	do
		# Cada una de estas url sera empleada como primer argumento en la ejecución del sript download.sh
#		bash scripts/download.sh $url data 
#		echo 
#	done 
#else 
#	echo "No existe el listado de urls para descargar"
#	exit 1
#fi 

# Eliminación del bucle for para comenzar la descarga de archivos
# Verificar si el archivo donde estan las url existe mediante if con la opción -f 
if [ -f "list_urls.txt" ]
then 
	echo "Comienza el programa ..."
	bash scripts/download.sh list data 
	echo 
else 
	echo "No existe el listado de urls para descargar"
	exit 1
fi 

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
echo "Descargando secuencia contaminada ..."
# Lanzamiento del script download.sh especificando que descomprima el archivo y filtre por nucleolar 
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes "small nucleolar"
echo 

# Index the contaminants file
# Ejecucion del script index.sh especificando en los argumentos los directorios a emplear
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx
echo

# Merge the samples into a single file
# Empleo del bucle for para recorrer todos los nombres de cada archivo .fastq.gz almacenado en data
# Posteriormente, se emplea cut para obtener el nombre del archivo antes del primer guion y sin la ruta (solo nos quedamos con el nombre de la muestra)
# Y sort y uniq para ordenar y eliminar duplicados, quedandonos solo con los nombres de las muestras base (C57BL_6NJ y SPRET_EiJ)
for sample_id in $(ls data/*.fastq.gz | cut -d "-" -f1 | cut -d "/" -f2 | sort | uniq) #TODO
do
    bash scripts/merge_fastqs.sh data out/merged $sample_id
    echo
done

# TODO: run cutadapt for all merged files
# Creacion de los directorios para cutadapt
mkdir -p log/cutadapt
mkdir -p out/trimmed
# Empleo del bucle for para recorrer todos los nombres de cada archivo .fastq.gz almacenado en out/merged
for mer_name in out/merged/*.fastq.gz
do
	# Almacenamos el basename de los archivos en la variable sample y lanzamos el cutadapt
	sample=$(basename "$mer_name" .fastq.gz)
	# Comprobar si el archivo trimmed ya existe mediante un bucle if [-f]
	if [ -f "out/trimmed/${sample}_trimmed.fastq.gz" ]
	then
		echo "El archivo ya existe. Saltando ejecución del comando"
	else
		echo "Comenzando cutadapt de $sample"
		cutadapt \
			-m 18 \
			-a TGGAATTCTCGGGTGCCAAGG \
			--discard-untrimmed \
			-o out/trimmed/${sample}_trimmed.fastq.gz out/merged/${sample}.fastq.gz >> log/cutadapt/${sample}.log 2>&1
			# Almacena los archivos generados en la carpeta out/trimmed, a la vez que genera un log unico por muestra en la carpeta log/cutadapt
		echo "Finalizado el cutadapt, archivos creados alojados en out/trimmed"
	fi
done

# TODO: run STAR for all trimmed files
# Empleo del bucle for de manera similar al anterior, obteniendo los nombres de los archivos y almacenandolos en la variable trim_name
for trim_name in out/trimmed/*.fastq.gz 
do
    # you will need to obtain the sample ID from the filename
    sid=$(basename "$trim_name" _trimmed.fastq.gz)
    # Comprobar que existe el directorio del indexado con el bucle if [-d]
    if [ -d out/star/$sid ]
    then 
		echo "El alineamiento para $sid ya se ha llevado a cabo. Saltando comando"
	else
		mkdir -p out/star/$sid
		echo "Ejecutando alineamiento con STAR para $sid..."
		STAR --runThreadN 4 \
			--genomeDir res/contaminants_idx \
			--outReadsUnmapped Fastx \
			--readFilesIn ${trim_name} \
			--readFilesCommand gunzip -c \
			--outFileNamePrefix out/star/$sid/ \
			> log/star_output.log 2>&1
		echo "Alineamiento finalizado para $sid. Datos almancenados en out/star/$sid/"
	fi
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in

# Damos un nombre al archivo y ubicación al log final y lo almacenamos en una variable
log_final="log/pipeline.log"

# Timestamp para el log
echo "Resultados generados el: $(date +'%Y-%m-%d %H:%M:%S')" >> $log_final

# Empleo de bucles for para obtener el nombre de los diversos log y almacenarla en log_cut
echo "==== Resultados cutadapt ====" >> ${log_final}
for log_cut in log/cutadapt/*.log
do
	# Creación del archivo log de acuerdo con las especificaciones para los resultados de Cutadapt
	echo "Procesando archivo de log: ${log_cut}"
	# Asignarle nombre a la muestra
	echo "Muestra: $(basename ${log_cut} .log)" >> ${log_final}
	# Recoger las lineas de interes con el comando grep -E
	grep -E "Reads with adapters|Total basepairs" ${log_cut} >> ${log_final}
	echo "" >> ${log_final} # linea vacia para separar los log
done

# Empleo de bucles for para obtener el nombre de los diversos subdirectorios donde se almacenan los log de STAR
echo "==== Resultados STAR ====" >> ${log_final}
for sample_star_dir in out/star/*/
do
	# Almacenamos en la variable log_star el Log.final.out de cada uno de los subdirectorios
	log_star="${sample_star_dir}Log.final.out"
	# Creación del archivo log de acuerdo con las especificaciones para los resultados de STAR
	echo "Procesando archivo de log: ${log_star}"
	echo "Muestra STAR: $(basename ${sample_star_dir})" >> ${log_final}
	# Recoger las lineas de interes con el comando grep -E
	grep -E "Uniquely mapped reads %|% of reads mapped to multiple loci|% of reads mapped to too many loci" ${log_star} >> ${log_final}
	echo "" >> ${log_final}  # linea vacia para separar los log
done

echo "El archivo de resultados ha sido creado con éxito en $log_final"

echo "############ Pipeline finalizada el $(date +'%Y-%m-%d %H:%M:%S')... ##############"
