# Licensing And Third-Party Notices Standard

## Family Baseline

Maintained CanDoItAll repositories use the unmodified **MIT License**. Start from
[`templates/repository/LICENSE`](../../templates/repository/LICENSE) and replace only
the copyright year and owner. Preserve any additional copyright lines that correctly
identify upstream work incorporated into the repository.

The project website, `https://aicandoitall.com`, remains the default public project URL,
but it is not a license condition. Do not add a website-link, advertising, attribution,
partner, or other condition to the MIT text.

An owner-approved legal exception must be explicit in the adopting repository and in any
package metadata. Do not silently substitute or modify a license.

## Repository Files And README

- Track the adapted license as `LICENSE` at the repository root.
- Link the README license badge and license section to `LICENSE`.
- Describe the license as `MIT`, not as a modified or custom license.
- Use the canonical MIT permission grant, single retention condition, and warranty
  disclaimer without additional conditions.
- Keep project, product, contribution, and partner links outside the license text.

## NuGet Packages

NuGet-producing repositories declare the SPDX expression directly:

```xml
<PropertyGroup Condition="'$(IsPackable)' == 'true' and '$(PackageLicenseExpression)' == '' and '$(PackageLicenseFile)' == ''">
  <PackageLicenseExpression>MIT</PackageLicenseExpression>
</PropertyGroup>
```

- Do not set `PackageLicenseFile` for the family MIT license.
- Inspect packed `.nuspec` metadata and require
  `<license type="expression">MIT</license>`.
- Keep the repository-root `LICENSE` for source distributions and repository readers;
  it does not need to be embedded merely to describe the NuGet package license.
- Keep NuGet `PackageProjectUrl` equal to `https://aicandoitall.com`; keep
  `RepositoryUrl` pointed at the package's canonical source repository.

Use
[`templates/repository/dotnet/Directory.Build.targets`](../../templates/repository/dotnet/Directory.Build.targets)
as the copy-ready baseline when centralizing package license, icon, and notice behavior.

## Third-Party Material

The repository MIT license covers CanDoItAll-authored work. It does not erase or replace
copyrights and licenses belonging to third parties.

Create a root `THIRD-PARTY-NOTICES.md` from
[`templates/repository/THIRD-PARTY-NOTICES.md`](../../templates/repository/THIRD-PARTY-NOTICES.md)
when the repository redistributes, vendors, copies, generates output from, or wraps
third-party material whose license or notice must accompany the distribution.

For every such component:

- record the component name and exact version or source revision;
- record the upstream project and source URL;
- explain which repository or package artifacts contain it;
- preserve the upstream copyright notice and SPDX identifier when available;
- include the complete required license or notice text in the notice document or a
  stable adjacent file;
- retain license banners and bundled-license comments in minified or generated assets;
- pack the notice with every NuGet package that contains the third-party material.

Do not claim third-party code, vendored or wrapped JavaScript/CSS, fonts, media, models,
generated output, or other assets as solely CanDoItAll-authored. Do not assume that a
wrapper changes the wrapped component's license.

Ordinary NuGet, npm, or other package-manager dependencies that are resolved separately
and are not copied into a repository or release artifact remain governed by the metadata
and notices in their own distributions. Keep lock files and dependency metadata
reviewable, and add a notice when a dependency's license requires attribution even
without vendoring.

Before release, compare the notice inventory with vendored directories, generated
browser assets, copied source headers, package contents, and dependency lock files.
