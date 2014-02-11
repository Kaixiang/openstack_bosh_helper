# OpenstackBoshHelper

This cli(script) helps you to deploy microbosh/cf to bluebox openstack env (WIP)


## Installation

Add this line to your application's Gemfile:

    gem 'openstack_bosh_helper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install openstack_bosh_helper

## Usage

1. Get your openstack rc file and source it
    
    ```
    source <my-rc.sh>
    ```
1. Generate ssh key

    ```
    ./bin/obh keygen
    ```
    
1. Upload key and create security group
    ```
    ./bin/obh prep
    ```

1. Generate Microbosh Manifest
    ```
    ./bin/obh gm
    input a pre allocated floating ip
    and the internal network id
    then a deployment file will be generated
    ```

1. microbosh deploy
    ```
    ./bin/obh dm
    ```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
