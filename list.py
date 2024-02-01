import boto3

def list_resources(service_name, region_name):
    session = boto3.Session(region_name=region_name)

    # Initialize the service resource
    service_resource = session.resource(service_name)

    resource_collections = [collection for collection in service_resource.meta.resource_model.collections]

    for resource_type in resource_collections:

        # Access the collection dynamically
        if hasattr(service_resource, resource_type.name):
            collection = getattr(service_resource, resource_type.name)
            try:
                # Attempt to list all resources of the type
                print(f"Evaluating: '{resource_type.name}':")
                for resource in collection.all():
                    print(resource.id)
                print("")
            except AttributeError as e:
                print(f"Error: {e}")
                print(f"The resource type '{resource_type.name}' may not support the 'all()' method.")
        else:
            print(f"Resource type '{resource_type.name}' not found in '{service_name}' service.")

# Example usage
        
service_name = 'ec2'
region_name = 'us-east-1'

list_resources(service_name, region_name)
