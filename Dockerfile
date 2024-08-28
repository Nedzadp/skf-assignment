FROM python:3.12-slim
LABEL authors="Nedzad Paradzik"

# Set environment variables to prevent compiled Python bytecode files writting to disk
ENV PYTHONDONTWRITEBYTECODE=1
# Disable output buffering
ENV PYTHONUNBUFFERED=1

# Set the working directory in the container
WORKDIR /app

COPY dependencies.txt /app/

# Install any necessary dependencies specified in dependencies.txt
RUN pip install --no-cache-dir -r dependencies.txt

# Copy the rest of the application code into the container
COPY . /app/

# Create a non-root user to run application with limited privileges.
RUN useradd -m flaskuser
RUN chown -R flaskuser:flaskuser /app

# Switch to the non-root user
USER flaskuser

# Expose the port that the Flask app runs on
EXPOSE 8082

# Set the default command to run the Flask application
CMD ["python", "app.py"]