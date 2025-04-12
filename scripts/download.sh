# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output

# Argumentos
url=$1
data=$2
descomprimir=$3
filtrar_palabra=$4

# Creacion del directorio con mkdir y la opcion -p
mkdir -p ${data}
echo "Directorio de descargas creado"

# Descarga del archivo
echo "Descargando archivo desde $url"
# Obtener el nombre del archivo descargado empleando el comando basename
filename=$(basename ${url})
file_path=${data}/${filename}
# Verificar si ya estan descargados los archivos con el comando if [-f]. Si no existen, los descarga en la carpeta indicada por el argumento
if [ -f "${file_path}" ]
then
    echo "El archivo ya está descargado: ${file_path}"
    exit 0
else
	# En caso de que el primer argumento sea list, se ejecutara el comando wget con la opcion -i, que recoge cada url del archivo de texto y procede a su descarga
	if [ "$url" == "list" ]
	then
		wget -P ${data} -i list_urls.txt # Con la opción -P guarda los archivos en el directorio indicado
	# En caso de que el primer argumento sea otra cosa, lo utilizara como url de descarga 
	else
		wget -P ${data} ${url}
	fi
fi

# Comprobación del hash de los archivos
# Generamos una variable con la que obtener la suma de verificación md5
url_md5=${url}.md5
# Obtencion del hash. Primero se descarga mediante el comando curl -s (para no mostrar el progreso de descarga)
# Luego se almacena en la variable solo el primer campo correspondiente al hash md5 mediante el comando awk
hash=$(curl -s "$url_md5" | awk '{ print $1 }')
# Calculo de la suma md5 del archivo descargado mediante md5sum
calculo_md5=$(md5sum "$file_path" | awk '{ print $1 }')
# Comprobacion de que los hash son correctos. En caso contrario, detiene la ejecución del programa
if [ "$hash" == "$calculo_md5" ]
then
	echo "Los archivos tienen el HASH md5 correcto"
else
	echo "El md5 no coincide con el de los archivos"
	exit 1
fi

# Descomprimir el archivo con gunzip, empleando la opcion -k para no eliminar el archivo original
if [ "$descomprimir" == "yes" ] 
then
    echo "Descomprimiendo el archivo $filename"
    gunzip -k ${file_path}
    echo "Descompresion con exito"
fi

# Filtrar las secuencias en el archivo si se especifica una palabra de filtro
if [ -n "$filtrar_palabra" ] 
then
    echo "Filtrando secuencias que contienen la palabra '$filtrar_palabra' en los encabezados..."
    # Usamos seqkit junto a grep -v (selecciona las lineas que no contienen el patron) -i (no distingue entre mayusculas y minusculas) -n (trata al patron como un nombre literal) y -p (indica el patron de filtro) 
    # A traves de estas opciones, el comando filtra y elimina las secuencias que contienen el patron, almacenandolas en un archivo temporal
    seqkit grep -v -i -n -p "${filtrar_palabra}" ${file_path} > ${file_path}.temp
    mv ${file_path}.temp ${file_path}  # Sobrescribe el archivo original con las secuencias filtradas del temporal
    echo "El archivo filtrado está en: $data"
fi
