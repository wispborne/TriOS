import os
import zipfile

def zip_dir(src_dir, zip_file, exclude_dirs):
    with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(src_dir):
            # Skip excluded directories
            dirs[:] = [d for d in dirs if os.path.join(root, d) not in exclude_dirs]

            for file in files:
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, src_dir)
                zip_path = os.path.join('TriOS', relative_path)
                zf.write(file_path, zip_path)

if __name__ == '__main__':
    src_dir = os.path.abspath('./build/windows/x64/runner/Release')
    zip_file = 'TriOS-Windows.zip'
    exclude_dirs = {
        os.path.abspath('./build/windows/x64/runner/Release/data/flutter_assets/assets/linux'),
        os.path.abspath('./build/windows/x64/runner/Release/data/flutter_assets/assets/macos'),
    }

    print(f'Creating {zip_file} excluding: {exclude_dirs}')
    zip_dir(src_dir, zip_file, exclude_dirs)
    print(f'{zip_file} created successfully.')
