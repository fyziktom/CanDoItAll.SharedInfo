# Licensing Standard

## Family Baseline

Maintained CanDoItAll repositories use the
**MIT-Derived License with Source Link Requirement**. Start from
[`templates/repository/LICENSE`](../../templates/repository/LICENSE) and replace the
copyright year, owner, and canonical source-repository URL.

Except for the repository-specific fields, use the same license text as
`CanDoItAll.Components`. The license preserves the normal MIT permissions and warranty
disclaimer, with one additional condition: a source or binary redistribution of the
software or a substantial portion of it must include a link to the original source
repository. The link must identify the repository that owns the redistributed software;
do not use a generic organization page or the public project website.

An owner-approved legal exception must be explicit in the adopting repository and in any
package metadata. Do not silently substitute another license or remove the source-link
condition.

## Repository Files And README

- Track the adapted license as `LICENSE` at the repository root.
- Link the README license badge and license section to `LICENSE`.
- Describe it as “MIT-derived with source-link requirement,” not plain “MIT.”
- Keep the canonical repository URL in the added condition current after a repository
  transfer or rename.
- Preserve the copyright notice, both conditions, and warranty disclaimer.

## NuGet Packages

The added source-link condition means this license is not the unmodified SPDX `MIT`
license. NuGet-producing repositories must therefore embed the license file:

```xml
<PropertyGroup Condition="'$(IsPackable)' == 'true' and '$(PackageLicenseExpression)' == '' and '$(PackageLicenseFile)' == ''">
  <PackageLicenseFile>LICENSE</PackageLicenseFile>
  <_UseRepositoryPackageLicense>true</_UseRepositoryPackageLicense>
</PropertyGroup>
<ItemGroup Condition="'$(_UseRepositoryPackageLicense)' == 'true'">
  <None Include="$(MSBuildThisFileDirectory)LICENSE"
        Pack="true"
        PackagePath="\"
        Link="LICENSE" />
</ItemGroup>
```

- Do not declare `<PackageLicenseExpression>MIT</PackageLicenseExpression>` while the
  source-link condition is present.
- Inspect packed `.nuspec` metadata and require `<license type="file">LICENSE</license>`.
- Inspect the archive and require a package-root `LICENSE` that is byte-for-byte identical
  to the adapted repository-root file.
- Keep NuGet `RepositoryUrl` equal to the source URL named by the license.

Use
[`templates/repository/dotnet/Directory.Build.targets`](../../templates/repository/dotnet/Directory.Build.targets)
as the copy-ready baseline when centralizing this behavior.
