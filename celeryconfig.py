task_serializer = "pickle"
broker_url = 'pyamqp://guest@localhost//'
accept_content = ['json','pickle']
result_backend = "rpc://"

# List of modules to import when the Celery worker starts.
#imports = ('comedian.lib.tasks',)

