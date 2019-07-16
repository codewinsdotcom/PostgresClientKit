Pod::Spec.new do |spec|
  spec.name     = "PostgresClientKit"
  spec.version  = "0.3.1"
  spec.summary  = "A PostgreSQL client library for Swift. Does not require libpq."
  spec.homepage = "https://github.com/codewinsdotcom/PostgresClientKit"
  spec.license  = "Apache License, Version 2.0"
  spec.author   = "David Pitfield"

  spec.description    = <<-DESC
      PostgresClientKit provides a friendly Swift API for operating against a PostgreSQL database.

      Features:

      - Doesn't require libpq
      - Developer-friendly API using modern Swift
      - Safe conversion between Postgres and Swift types
      - Memory efficient
      - SSL/TLS support
                   DESC

  spec.swift_version         = "5.0"
  spec.ios.deployment_target = "10.0"
  spec.osx.deployment_target = "10.12"
  spec.source                = { :git => "https://github.com/codewinsdotcom/PostgresClientKit.git", :tag => "v#{spec.version}" }
  spec.source_files          = "Sources/**/*.swift"
  
  spec.dependency "BlueSocket", "~> 1.0"
  spec.dependency "BlueSSLService", "~> 1.0"
end
