from flask import render_template, request, flash
from elasticsearch import Elasticsearch
from elasticsearch.exceptions import ConnectionError
import os

# Initialize Elasticsearch client
es_url = os.getenv('ELASTICSEARCH_URL')
es_username = os.getenv('ELASTICSEARCH_USERNAME')
es_password = os.getenv('ELASTICSEARCH_PASSWORD')

# Use basic authentication method to access elastic search server
es = Elasticsearch(es_url, basic_auth=(es_username, es_password))

# Setup app routes GET and POST method for path '/' should land to index() function
def setup_routes(app):
    @app.route('/', methods=['GET', 'POST'])
    def index():

        # indices_with_sizes list needs to be defined because it is used in the template
        indices_with_sizes = []

        # If request method is POST on path '/' this means form is submitted
        if request.method == 'POST':

            try:
                # To retrieve indices and size we could use cat indices API
                # There is important message from Elasticsearch official documentation regarding cat indices API
                # cat APIs are only intended for human consumption using the command line or Kibana console. They are not intended for use by applications.
                # So, we will first perform get all indexes and then perform get stats for those indexes to retrieve sizes.

                # Retrieve all indices from Elasticsearch
                all_indices = es.indices.get(index="*")

                # Get num_indices from the form
                num_indices = request.form['num_indices']

                if num_indices == "":
                    # If num_indices is empty, return all indices
                    limited_indices = list(all_indices.keys())
                else:
                    # Otherwise, limit the number of indices
                    limited_indices = list(all_indices.keys())[:int(num_indices)]

                # Use stats API to get sizes for all limited indices in one call
                stats = es.indices.stats(index=",".join(limited_indices), metric='store')
                # Extract index names and sizes
                indices_with_sizes = [
                    {'name': index, 'size_in_bytes': stats['indices'][index]['total']['store']['size_in_bytes']} for index in limited_indices
                ]
                # Render index.html but with list of indices and flag submitted=True to display only results and hide input form
                return render_template('index.html', indices=indices_with_sizes, submitted=True)

            except ConnectionError as e:
                # Handle connection errors to Elasticsearch
                error_message = f"Connection error: {str(e)}"
                flash(error_message, 'error')
                return render_template('index.html', indices=indices_with_sizes, submitted=False)

            except Exception as e:
                # Handle any other unexpected errors
                error_message = f"An unexpected error occurred: {str(e)}"
                flash(error_message, 'error')
                return render_template('index.html', indices=indices_with_sizes, submitted=False)

        # If GET is performed on / we will show index.html with flag submitted=False to indicate to load input form
        return render_template('index.html', indices=indices_with_sizes, submitted=False)
