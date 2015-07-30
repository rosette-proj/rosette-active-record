[![Build Status](https://travis-ci.org/rosette-proj/rosette-active-record.svg)](https://travis-ci.org/rosette-proj/rosette-active-record) [![Code Climate](https://codeclimate.com/github/rosette-proj/rosette-active-record/badges/gpa.svg)](https://codeclimate.com/github/rosette-proj/rosette-active-record) [![Test Coverage](https://codeclimate.com/github/rosette-proj/rosette-active-record/badges/coverage.svg)](https://codeclimate.com/github/rosette-proj/rosette-active-record/coverage)

rosette-active-record
====================

## Installation

`gem install rosette-active-record`

Then, somewhere in your project:

```ruby
require 'rosette/data_stores/active_record_data_store'
```

### Introduction

This library is generally meant to be used with the Rosette internationalization platform that extracts translatable phrases from git repositories. rosette-active-record provides an ActiveRecord-based data store to Rosette responsible for storage and retrieval of all Rosette data.

### Usage with rosette-server

Let's assume you're configuring an instance of [`Rosette::Server`](https://github.com/rosette-proj/rosette-server). Adding rosette-active-record as your data store would cause your configuration to look something like this:

```ruby
# config.ru
require 'rosette/core'
require 'rosette/data_stores/active_record_data_store'

rosette_config = Rosette.build_config do |config|
  config.use_datastore(
    'active-record', { adapter: 'mysql2', host: '127.0.0.1', port: '3306', ... }
  )
end

server = Rosette::Server::ApiV1.new(rosette_config)
run server
```

### Models

1. `Phrase`. Phrases represent a single unit of translatable content and consist of a `key` (the source text), a `meta_key` (a unique identifier), and a few other properties like `file` and `line_number`.

2. `CommitLog`. Rosette identifies translatable content at the git commit level. Each `CommitLog` entry represents the current state of a single commit, and contains the `commit_id` of the commit, the current `status` of the commit (see [Rosette::DataStores::PhraseStatus](http://www.rubydoc.info/github/rosette-proj/rosette-core/master/Rosette/DataStores/PhraseStatus)), and the commit's `branch_name`.

3. `CommitLogLocale`. As translations become available, `CommitLogLocale` entries are created and updated to track translation progress. Progress is stored in the `translated_count` field.

### Migrations and Rake Tasks

As this project matures, new migrations will be added to the `migrations/` folder. In true activerecord fashion, migrations are additive and run via a rake task. In your project, add this to your Rakefile:

```ruby
require 'rosette/data_stores/active_record/tasks'
```

You should then be able to run `bundle exec rake rosette:ar:migrate`.

In addition to migrations, you should also now be able to run `rake rosette:ar:rollback` to roll back a migration, and `rake rosette:ar:setup` to create the `schema_migrations` table and run all migrations (when you're bootstrapping a new database, for example).

## Requirements

This project must be run under jRuby. It uses [expert](https://github.com/camertron/expert) to manage java dependencies via Maven. Run `bundle exec expert install` in the project root to download and install java dependencies.

rosette-active-record also reqires a JDBC-friendly database adapter. See [this github repo](https://github.com/jruby/activerecord-jdbc-adapter) for the right adapter for your database. You'll need to include the adapter gem in your gemfile, require it, and make sure you pass the correct `adapter` option to `#use_datastore` (see above).

## Running Tests

`bundle exec rake` or `bundle exec rspec` should do the trick.

## Authors

* Cameron C. Dutro: http://github.com/camertron
