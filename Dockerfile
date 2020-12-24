FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build

ADD . /app
WORKDIR /app
RUN dotnet publish -c Release -p:BlazorEnableCompression=false -p:BlazorCacheBootResources=false
RUN ls -al /app/bin/Release/net5.0/publish/wwwroot/_framework

#

FROM nginx:alpine

ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./cert.pem /etc/nginx/cert.pem
ADD ./privkey.pem /etc/nginx/privkey.pem

COPY --from=build /app/bin/Release/net5.0/publish/wwwroot /var/www/html
