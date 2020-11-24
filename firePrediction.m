%https://openweathermap.org/current
%https://www.mathworks.com/matlabcentral/answers/417426-how-to-gather-data-from-weather-forecast

%Dependencia:
%https://www.mathworks.com/matlabcentral/fileexchange/28518-xml2struct

%close all;
clear all; 
clc;

    sns = aws.sns.Client();
    sns.initialize;
    
    topicARN = 'arn:aws:sns:sa-east-1:712436499354:prediction-fire-topic';
      
    latitude  = '-22.97331272';
    longitude = '-47.0470176';
    
    arquivoHistorico = strcat('umidade',latitude,longitude,'.txt');
    
    historicoData = readmatrix(arquivoHistorico);
    
    %Pegando os dados da API-----------------------------------------------
    key = 'YOURKEYHERE';
    url = ['https://api.openweathermap.org/data/2.5/weather?lat=',latitude,'&lon=',longitude,'&appid=',key,'&mode=','xml'];
    Current_Data = webread(url);
    
    fid = fopen('data.xml','wt');
    fprintf(fid, '%s\n', Current_Data);
    fclose(fid);
    
    Data = xml2struct('data.xml');
    
    umidade = Data.current.humidity.Attributes.value;       
    if Data.current.precipitation.Attributes.mode == 'no'
        precipitacao = '0';
    else 
        precipitacao = Data.current.precipitation.Attributes.value;
    end

    umidade = str2double(umidade);               %valor em '%'
    precipitacao = str2double(precipitacao);     %valor em 'mm'   
    %======================================================================
    
    %Calculando o N da FMA ------------------------------------------------
    if precipitacao < 12.9
        historicoData = [historicoData; umidade];
        sizeOfMatrix = size(historicoData);
    else
        historicoData = [umidade];
    end
    %======================================================================
    
    %Calculando FMA--------------------------------------------------------
    FMA = 0;
    
    for i = 1 : sizeOfMatrix
        FMA = FMA + 100/historicoData(i,1);
    end
    
    if FMA < 1
        chance = 'Alerta Diário: Chances de Incêndio Nulas.'
    else if FMA < 3
            chance = 'Alerta Diário: Chances Pequenas de Incêndio.'
         else if FMA < 8
                chance = 'Alerta Diário: Cuidado! Chances Médias de Incêndio.'
              else if FMA < 20
                    chance = 'Alerta Diário: Cuidado! Chances ALTAS de Incêndio!'
                   else
                    chance = 'Alerta Diário: PERIGO! Chances MUITO ALTAS de Incêndio!'
                  end
             end
        end
    end
    %======================================================================
    
    %Enviando SNS ---------------------------------------------------------
    dataEhora = char(datetime('now','Format','yyyy-MM-dd''T''HH:mm:ss''Z'''));

    %mandando SNS
    s = struct('eventDate',dataEhora,'latitude',latitude,'longitude',longitude,'message',chance);
    jsonS = jsonencode(s);    

    sns.publish(topicARN, jsonS);
    %======================================================================

%Fechando Arquivo e Atualizando o Banco de Dados --------------------------
fid = fopen(arquivoHistorico,'wt');
fprintf(fid, '%d\n', historicoData);
fclose(fid);
%==========================================================================

%Fim do Script ------------------------------------------------------------
disp('DONE');
