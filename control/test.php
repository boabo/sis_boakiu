<?php
ob_start();
session_start();

$curl = curl_init();

curl_setopt_array($curl, array(
    CURLOPT_URL => 'https://apind.boa.bo/api/boa-stage-nd/Ticket/getTicketInformation',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_ENCODING => '',
    CURLOPT_MAXREDIRS => 10,
    CURLOPT_TIMEOUT => 0,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_POSTFIELDS =>'{
    "ticketNumber": 9302408660650,
     "convertTo": "BO",
     "recursive":false
}',
    CURLOPT_HTTPHEADER => array(
        'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjIsImlhdCI6MTY2NzMzMzY0NzYwNSwiZXhwIjoxNjY3MzY0NzUxNjA1fQ.ymogpZli5eqdCayth9KcZjww8yXpUoGOa9O0ufqHGyU',
        'Content-Type: application/json',
        'Cookie: connect.sid=s%3A93azwJMG5KdD0wkge7d3lIW0BDsyVNJ1.o27MuhL9RoOxQwGjxz7IVpz%2FBET7IY4lQJR7KSTBFCA'
    ),
));
curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($curl);

if(curl_errno($curl)) {
    echo 'Error:' . curl_error($curl);
}

curl_close($curl);

echo $response;


/*$curl = curl_init();

curl_setopt_array($curl, array(
    //CURLOPT_URL => $_SESSION['_PXP_ND_URL'].'/api/boa-stage-nd/Ticket/getTicketInformation',
    CURLOPT_URL => 'https://apind.boa.bo/api/boa-stage-nd/Ticket/getTicketInformation',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_ENCODING => '',
    CURLOPT_MAXREDIRS => 10,
    CURLOPT_TIMEOUT => 0,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_POSTFIELDS =>'{
                "ticketNumber": 9302408660650,
                "recursive": false
            }
            ',
    CURLOPT_HTTPHEADER => array(
        'Authorization: ' . $_SESSION['_PXP_ND_TOKEN'],
        'Content-Type: application/json'
    ),
));

$response = curl_exec($curl);


curl_close($curl);
echo $response;
exit;*/