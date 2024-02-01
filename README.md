# nuvei

## organization
- the project assumes a consul container is up and running. To facilitate this, there is a script under the secrets directory ( consul.sh ). As long as docker is available this should work. The purpose of consul is just to store the state for the terraform project. The backend could have been done using s3, buti wanted to try using consul and i think it gives a more zen feel to have the secrets on vault and the state on consul. 

- the terraform script needs refactoring to modularize the whole thing. I started using the aws modules prebuilt by aws, but i did not like the naming convention and i wanted to have everything working before modularizing.
- some resources are untested ( ssl certificate is a glaring one ) others "work" like the route53 zone and cname record, but since i dont have a domain to use, the validation is unable to complete. I suspect that there might be a timing issue due to having to wait for validation. This can be done with a PR ( to add/remove the validation for the records, but it felt out of scope )

## resource discovery with python
- the script list_alt.py is the better one to list the objects, i have a couple of bugs currently ( takes too much time/memory to run, some resources are borked because i tried to be as dynamic as possible -- discovering the services as opossed to creating static functions for each type --, the ammount of api calls that boto3 makes pushes the throtling limit dangerously close, etc )
- this needs the boto3 library to be installed. I used python3 -m venv boto3; source boto3/bin/activate; pip install boto3 to configure the one i was testing with.

## closing

in general this complies with the request but given more time everything could stand more polish. 