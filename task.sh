set -e

if [ "$1" == "test" ]; then
    if [ "$2" == "d" ] ; then # down
        echo "Stopping tests..."
        sudo docker compose -f "test.docker-compose.yml" down
        exit 0
    fi
    if [ "$2" == "" ]; then # up
        echo "Running tests..."
        sudo docker compose -f "test.docker-compose.yml" up -d --build
        exit 0
    fi
fi
if [ "$1" == "fuzz" ]; then
    if [ "$2" == "d" ]; then
        echo "Stopping fuzzing..."
        sudo docker compose -f "fuzzing.docker-compose.yml" down
        exit 0
    fi
    if [ "$2" == "" ]; then # up
        echo "Running fuzzing..."
        sudo docker compose -f "fuzzing.docker-compose.yml" up -d --build
        exit 0
    fi
fi

echo "Usage: ./task.sh test|fuzz [d]" # d for down