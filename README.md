# ActiveSupport

Port of Rails' ActiveSupport Gem, still in the early stages of development. A lot of code has been copy-pasted from [rails/activesupport](https://github.com/rails/rails/blob/master/activesupport), so some things in the documentation may not be applicable and some things may just not work.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  active_support:
    github: watzon/active_support.cr
```

## Usage

```crystal
require "active_support"
```

## Development

I want to port all of the functionality in ActiveSupport that's actually useful in Crystal and not just Ruby specific patches. Here is a list of things that I would like to see ported:

- [x] Duration
- [x] Inflections/Inflector
- [ ] I18n Patches for [vladfaust/i18n.cr](https://github.com/vladfaust/i18n.cr)
  - [ ] Transliteration
- [x] StringInquirer
- [ ] TimeZones
- [ ] More..?

## Contributing

1. Fork it ( https://github.com/watzon/activesupport/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [watzon](https://github.com/watzon) Chris Watson - creator, maintainer
