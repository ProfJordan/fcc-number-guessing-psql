#!/bin/bash

# prompt user for username
read -p "Enter your username:" username

# connect to psql database
# assumes you have psql installed and a database named "number_guess" set up
# also assumes you have a table named "users" with columns "username", "games_played", "best_game"
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
$PSQL "CREATE TABLE IF NOT EXISTS users (username varchar(22) PRIMARY KEY, games_played integer DEFAULT 0, best_game integer DEFAULT NULL);" || exit 1

# check if username exists in database
user_info=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$username';")

if [ -z "$user_info" ]; then
  # username doesn't exist in database
  echo "Welcome, $username! It looks like this is your first time here."
  user_info="0|NULL"
else
  # username exists in database
  IFS='|' read -r games_played best_game <<< "$user_info"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

# generate secret number
secret_number=$(( RANDOM % 1000 + 1 ))

# prompt user to guess the secret number
guesses=0
while true; do
  read -p "Guess the secret number between 1 and 1000:" guess

  # check if input is an integer
  if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  (( guesses++ ))

  # check if guess is correct
  if (( guess == secret_number )); then
    echo "You guessed it in $guesses tries. The secret number was $secret_number. Nice job!"
    break
  elif (( guess > secret_number )); then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# update database with user's stats
$PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$username', 1, $guesses) ON CONFLICT (username) DO UPDATE SET games_played = users.games_played + 1, best_game = CASE WHEN $guesses < users.best_game OR users.best_game IS NULL THEN $guesses ELSE users.best_game END;"
