mysql-create-database() 
{
    if [[ $# -ge 1 ]]; then
        echo "CREATE DATABASE ${1} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" | mysql -v "${@:2}"
    fi;
}
