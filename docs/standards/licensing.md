# Licensing Standard

## Family Baseline

Maintained CanDoItAll repositories use the
**MIT-Derived License with CanDoItAll Website Link Requirement**. Start from
[`templates/repository/LICENSE`](../../templates/repository/LICENSE) and replace the
copyright year and owner. Keep the shared website URL unchanged.

The license preserves the normal MIT permissions and warranty disclaimer, with one
additional condition: a source or binary redistribution of the software or a substantial
portion of it must include at least one link to the main CanDoItAll website,
`https://aicandoitall.com`. One such link satisfies the added condition for a
redistribution containing multiple CanDoItAll libraries covered by this license. The
individual copyright and permission notices must still be retained as required by the
first condition.

An owner-approved legal exception must be explicit in the adopting repository and in any
package metadata. Do not silently substitute another license, change the shared website
URL, or remove the website-link condition.

## Repository Files And README

- Track the adapted license as `LICENSE` at the repository root.
- Link the README license badge and license section to `LICENSE`.
- Describe it as “MIT-derived with CanDoItAll website-link requirement,” not plain “MIT.”
- Keep `https://aicandoitall.com` in the added condition; do not substitute a repository
  URL.
- Preserve the copyright notice, both conditions, and warranty disclaimer.

## NuGet Packages

The added website-link condition means this license is not the unmodified SPDX `MIT`
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
  website-link condition is present.
- Inspect packed `.nuspec` metadata and require `<license type="file">LICENSE</license>`.
- Inspect the archive and require a package-root `LICENSE` that is byte-for-byte identical
  to the adapted repository-root file.
- Keep NuGet `PackageProjectUrl` equal to `https://aicandoitall.com`; keep `RepositoryUrl`
  pointed at the package's canonical source repository.

Use
[`templates/repository/dotnet/Directory.Build.targets`](../../templates/repository/dotnet/Directory.Build.targets)
as the copy-ready baseline when centralizing this behavior.
