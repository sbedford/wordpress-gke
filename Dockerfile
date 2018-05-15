FROM wordpress:latest

RUN apt-get update && \
	apt-get install -y  --no-install-recommends ssl-cert && \
	rm -r /var/lib/apt/lists/* && \
	a2enmod ssl && \
	a2ensite default-ssl

COPY wp-stateless /usr/src/wordpress/wp-content/plugins/wp-stateless-media
RUN chown -R www-data:www-data /usr/src/wordpress/wp-content/plugins/

EXPOSE 80
EXPOSE 443