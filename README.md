# EF Migrations Demo

Initial migration (`InitialCreate`) generated with:

```sh
docker run \
    --rm \
    --volume "$(pwd):/src" \
    --workdir /src \
    --env "ConnectionStrings__DefaultConnection=Host=placeholder" \
    mcr.microsoft.com/dotnet/sdk:8.0 /bin/bash -c "\
    dotnet tool install --global dotnet-ef --version 8.* && \
    export PATH=\"\$PATH:/root/.dotnet/tools\" && \
    dotnet restore && dotnet ef migrations add InitialCreate \
    "
```

## Authors

**Andre Silva** - [@andreswebs](https://github.com/andreswebs)

## License

This project is licensed under the [Unlicense](UNLICENSE).
