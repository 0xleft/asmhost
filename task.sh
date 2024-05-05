set -e

if [ "$1" == "test" ]; then
    echo "Running tests..."
    sudo docker compose -f "test.docker-compose.yml" up --build
    exit 0
fi
if [ "$1" == "fuzz" ]; then
    echo "Running fuzzing..."
    sudo docker compose -f "fuzzing.docker-compose.yml" up --build
    exit 0
fi

echo "Usage: ./task.sh test|fuzz" 