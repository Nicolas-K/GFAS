%https://github.com/mathworks-ref-arch/matlab-aws-dynamodb
%https://sa-east-1.console.aws.amazon.com/dynamodb/home?region=sa-east-1#tables:selected=myTableName;tab=overview

%close all;
clear all; 
clc;

    sns = aws.sns.Client();
    sns.initialize;
    
    topicARN = 'arn:aws:sns:sa-east-1:712436499354:fire-notification-topic';  


%1  - Coastal Aerosol
%2  - Blue
%3  - Green
%4  - Red
%5  - NIR
%6  - SWIR 1
%7  - SWIR 2
%8  - Panchromatic
%9  - Cirrus
%10 - TIR 1
%11 - TIR 2

fire = 0;

satelliteImage(:,:,1) = imread('H:/Projeto_Integrado/newDataset/[bestLC08_L1TP_044032_20181108_20181116_01_T1/LC08_L1TP_044032_20181108_20181116_01_T1_B1.TIF');
satelliteImage(:,:,2) = imread('H:/Projeto_Integrado/newDataset/[bestLC08_L1TP_044032_20181108_20181116_01_T1/LC08_L1TP_044032_20181108_20181116_01_T1_B2.TIF');
satelliteImage(:,:,3) = imread('H:/Projeto_Integrado/newDataset/[bestLC08_L1TP_044032_20181108_20181116_01_T1/LC08_L1TP_044032_20181108_20181116_01_T1_B3.TIF');
satelliteImage(:,:,4) = imread('H:/Projeto_Integrado/newDataset/[bestLC08_L1TP_044032_20181108_20181116_01_T1/LC08_L1TP_044032_20181108_20181116_01_T1_B4.TIF');
satelliteImage(:,:,5) = imread('H:/Projeto_Integrado/newDataset/[bestLC08_L1TP_044032_20181108_20181116_01_T1/LC08_L1TP_044032_20181108_20181116_01_T1_B5.TIF');
satelliteImage(:,:,6) = imread('H:/Projeto_Integrado/newDataset/[bestLC08_L1TP_044032_20181108_20181116_01_T1/LC08_L1TP_044032_20181108_20181116_01_T1_B6.TIF');
satelliteImage(:,:,7) = imread('H:/Projeto_Integrado/newDataset/[bestLC08_L1TP_044032_20181108_20181116_01_T1/LC08_L1TP_044032_20181108_20181116_01_T1_B7.TIF');

%%FCC for later comparison
FCC = satelliteImage(:,:,[7,5,1]); %SWIR2, NIR, Coastal Aerosol

%%Opening NIR and SWIR images
satelliteImageNIR = double(satelliteImage(:,:,[5])); %NIR
satelliteImageSWIR = double(satelliteImage(:,:,[7])); %SWIR2


%%DN to L (Calibrating)
gain5 = 0.876;      %Some constants for Calibration. No Blue Band, no DOS.
gain7 = 0.065;
offset5 = -2.39;
offset7 = -0.22;

lNIR = gain5 * satelliteImageNIR + offset5;
lSWIR = gain7 * satelliteImageSWIR + offset7;


%%Calculating P (Reflectance)
ezero5 = 1028;  %Some constants for Calculating P.
ezero7 = 83.49;

pNIR = pi * lNIR / ezero5;
pSWIR = pi * lSWIR / ezero7;

%%Checking for Reflectance < 0
pNIR(pNIR<0) = NaN;
pSWIR(pSWIR<0) = NaN;

%%Calculating the NDVI
tmNBR = (pNIR - pSWIR) ./ (pNIR + pSWIR);

%%Stretching 
stretchNBR = 127.5 * tmNBR + 127.5; %As NBR goes from -1 to 1, this grants it's streching (127.5=255/2)

fire = 1;
if fire == 1
    
    
    
    %%Create objeto Cliente para Criar objeto database
    %ddbClient = aws.dynamodbv2.AmazonDynamoDBClient;
    %ddbClient.initialize();

    %%Criando objeto Documento da database
    %ddb = aws.dynamodbv2.document.DynamoDB(ddbClient);

    %%Pegando a tabela de incendios
    %table = ddb.getTable('incendio');

    %%Criando um item da tabela 'incendio' e Adicionando à Tabela
    %UUID = char(java.util.UUID.randomUUID); %Gerando o ID
    %dataEhora = char(datetime('now'));      %Pegando Data e Hora
    dataEhora = char(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ss''Z'''))         %Pegando Data e Hora

    %item = aws.dynamodbv2.document.Item();
    %item.withPrimaryKey('id', UUID);
    %item.withString('date', dataEhora);
    %item.withString('latitude', '-100.30398');
    %item.withString('longitude', '-100.56679');
    %putItemOutcome = table.putItem(item);
    
    s = struct('eventDate',dataEhora,'latitude','-100.30398','longitude','-100.56679');
    jsonS = jsonencode(s);    

    sns.publish(topicARN, jsonS);    
end

disp('DONE');

%%Printing both images with a NBR Palette
%figure,
%subplot(1,2,1), imshow(uint8(stretchNBR));
%title('Normalized Burn Ratio - NBR');

%subplot(1,2,2), imshow(FCC);
%title('FCC (SWIR2, NIR, Coastal Aerosol)');
%colormap(autumn);



