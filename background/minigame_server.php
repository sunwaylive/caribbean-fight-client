<?php
use Workerman\Worker;
require_once '../workerman/Autoloader.php';

$rooms = array();
$connections = array();
$zys = array();

function proxy()
{
    $proxy_worker = new Worker("tcp://192.168.159.146:2347");
    $proxy_worker ->onMessage = function($connection, $data)
    {
        #echo "$data\n";
        $val = explode("|", $data);
        $cmd = $val[0];
        $cmd($val, $connection);
    };
}

function createRoom($data, $conn)
{
    global $rooms;
    global $zys; 
    $ip =  $conn->getRemoteIp();
    $port = $conn ->getRemotePort();
    #echo $ip;
    $rooms[$ip] = array($conn);
    $zys[$ip] = array(0, 0);
    #var_dump($rooms);
    $conn->send("ok");
}

function listRoom($data, $conn)
{
    global $rooms;
    
    $data = count($rooms);
    foreach($rooms as $key=>$val)
    {
        $data = $data . "|" . $key;
    }
    echo $data;
    $conn->send($data);
    #var_dump($rooms);
}

//data ip|zy
function addRoom($data, $conn)
{

    global $rooms;
    global $zys;

    $data = explode(":", $data[1]);
    #var_dump($data);
    $room_ip = $data[0];
    $zy = $data[1];
    $zy = checkZy($zy, $zys[$room_ip], $room_ip);
    array_push($rooms[$room_ip], $conn);
    $conn->send($zy);
    echo $zy;
    #var_dump($rooms);
}

function startGame($data, $conn)
{
    global $rooms;

    $create_ip = $conn->getRemoteIp();
    foreach($rooms as $ip=>$room)
    {
        if (strcmp($create_ip, $ip) == 0)
        {
            foreach($room as $user)
            {
                echo $user->getRemoteIp() . ":" . $user->getRemotePort() . "\n";
            }
        }
    }
}

function checkZy($zy, $data, $room_ip)
{
    global $zys;

    if($zy == 'A')
        return 'A2';
    else if($zy == 'B' && $data[0] == 0)
    {
        $zys[$room_ip][0] = 1;
        return 'B1';
    }
    else
        return 'B2';
}

function test()
{
// 创建一个Worker监听2347端口，不使用任何应用层协议
$tcp_worker = new Worker("tcp://192.168.159.146:2347");

// 启动4个进程对外提供服务
$tcp_worker->count = 4;

$tcp_worker->onConnect = function($connection)
{
    echo "connect";
};

// 当客户端发来数据时
$tcp_worker->onMessage = function($connection, $data)
{
    // 向客户端发送hello $data
    $connection->send('hello ' . $data);
};
}

// 运行worker
proxy();
Worker::runAll();
