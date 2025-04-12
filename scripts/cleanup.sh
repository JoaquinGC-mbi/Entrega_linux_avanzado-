# Argumentos 
data=$1
resources=$2
output=$3
logs=$4

# Limpieza de archivos
# Con un bucle if y la opcion [-ne (diferente a)] indicamos que si existen argumentos (definidos en "$#") en la ejecucion del script, se eliminen los directorios indicados por los argumentos
if [ "$#" -ne 0  ]
then
	echo "Se eliminaran las carpetas: $data $resources $output $logs"
	# Verificación de que existe el argumento mediante la opcion [-n] y, si existe, elimina los archivos indicados con rm -rf para borrar sin requerir confirmacion
	[ -n "$data" ] && rm -rf ${data}
    [ -n "$resources" ] && rm -rf ${resources}
    [ -n "$output" ] && rm -rf ${output}
    [ -n "$logs" ] && rm -rf ${logs}
else
	# Si no se detectan argumentos, se eliminaran todas las carpetas
	echo "Se eliminaran todas las carpetas menos la lista de urls y scripts"
	# Encuentra todas las carpetas presentes en el directorio Ejercicio_linux y la elimina con rm -rf, pero preservando el directorio raiz, la carpeta de scripts, la lista de urls y el readme.md 
	find /home/vant/Ejercicio_linux -mindepth 1 ! -path '/home/vant/Ejercicio_linux/scripts/*' ! -name 'scripts' ! -name 'list_urls.txt' ! -name 'README.md' -exec rm -rf {} +
fi

