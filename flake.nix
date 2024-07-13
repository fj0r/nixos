{
  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "flake:nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, plasma-manager, ... }: {

    nixosConfigurations = {
      workstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mobi/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.agent = import ./home;

            home-manager.sharedModules = [ plasma-manager.homeManagerModules.plasma-manager ];
            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ] ;
      };
      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/vbox/configuration.nix
        ] ;
      };
     };
    ## nix build .#iso
    ## nixcfg --build-iso && nixcfg --burn-iso 00000111112222333
    packages.x86_64-linux.iso = inputs.nixos-generators.nixosGenerate {
      system = "x86_64-linux";
      format = "install-iso";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./pkgs/iso
        {
          system.stateVersion = "24.05";
        }
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.agent = import ./home;

          # Optionally, use home-manager.extraSpecialArgs to pass
          # arguments to home.nix
        }
      ];
    };
  };
}
