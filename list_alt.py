import boto3
import json
# import pprint

# Create a PrettyPrinter object
# pp = pprint.PrettyPrinter(indent=4)

# regions = ['us-east-1', 'us-east-2', 'us-west-1', 'us-west-2']

# services = ['ec2', 's3']
            
regions = ['us-east-1', 'us-east-2']
services = ['ec2']
resource_type_filter = ['images', 'snapshots']

resources_by_region = {}

for region_name in regions:

    session = boto3.Session(region_name=region_name)

    resources_by_region[region_name] = {}

    for service_name in services:

        resources_by_region[region_name][service_name] = {}

        service_resource = session.resource(service_name)

        resource_collections = [collection for collection in service_resource.meta.resource_model.collections]

        for resource_type in resource_collections:
            resources_by_region[region_name][service_name][resource_type.name] = []

            # Access the collection dynamically
            if hasattr(service_resource, resource_type.name):
                collection = getattr(service_resource, resource_type.name)
                if resource_type.name not in resource_type_filter:
                    try:
                        # Attempt to list all resources of the type
                        for resource in collection.all():
                            resources_by_region[region_name][service_name][resource_type.name].append(resource.id)
                    except AttributeError as e:
                        print(f"Error: {e}")
                        print(f"The resource type '{resource_type.name}' may not support the 'all()' method.")
            else:
                print(f"Resource type '{resource_type.name}' not found in '{service_name}' service.")

# Pretty print the dictionary
# pp.pprint(resources_by_region)

# Convert the dictionary to a JSON string
json_data = json.dumps(resources_by_region, indent=4)

# Print the JSON string
print(json_data)
