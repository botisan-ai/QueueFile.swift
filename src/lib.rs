use std::path::Path;
use std::sync::Mutex;

use queue_file::QueueFile as RustQueueFile;

#[derive(Debug, thiserror::Error, uniffi::Error)]
#[uniffi(flat_error)]
pub enum QueueFileError {
    #[error("IO error: {0}")]
    IoError(String),
    #[error("Queue is empty")]
    EmptyQueue,
    #[error("Element too big")]
    ElementTooBig,
    #[error("Too many elements")]
    TooManyElements,
    #[error("Corrupted file: {0}")]
    CorruptedFile(String),
    #[error("Unsupported version: detected {detected}, supported {supported}")]
    UnsupportedVersion { detected: u32, supported: u32 },
    #[error("Lock acquisition error")]
    LockError,
}

impl From<queue_file::Error> for QueueFileError {
    fn from(e: queue_file::Error) -> Self {
        match e {
            queue_file::Error::Io { source } => QueueFileError::IoError(source.to_string()),
            queue_file::Error::ElementTooBig {} => QueueFileError::ElementTooBig,
            queue_file::Error::TooManyElements {} => QueueFileError::TooManyElements,
            queue_file::Error::CorruptedFile { msg } => QueueFileError::CorruptedFile(msg),
            queue_file::Error::UnsupportedVersion { detected, supported } => {
                QueueFileError::UnsupportedVersion { detected, supported }
            }
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, uniffi::Enum)]
pub enum OffsetCachePolicy {
    None,
    Linear { offset: u32 },
    Quadratic,
}

#[derive(uniffi::Object)]
pub struct QueueFile {
    inner: Mutex<RustQueueFile>,
}

#[uniffi::export]
impl QueueFile {
    #[uniffi::constructor]
    pub fn open(path: String) -> Result<Self, QueueFileError> {
        let queue = RustQueueFile::open(Path::new(&path))?;
        Ok(QueueFile {
            inner: Mutex::new(queue),
        })
    }

    #[uniffi::constructor]
    pub fn with_capacity(path: String, capacity: u64) -> Result<Self, QueueFileError> {
        let queue = RustQueueFile::with_capacity(Path::new(&path), capacity)?;
        Ok(QueueFile {
            inner: Mutex::new(queue),
        })
    }

    #[uniffi::method]
    pub fn add(&self, data: Vec<u8>) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        queue.add(&data)?;
        Ok(())
    }

    #[uniffi::method]
    pub fn add_multiple(&self, items: Vec<Vec<u8>>) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        queue.add_n(items)?;
        Ok(())
    }

    #[uniffi::method]
    pub fn peek(&self) -> Result<Option<Vec<u8>>, QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        match queue.peek()? {
            Some(boxed) => Ok(Some(boxed.to_vec())),
            None => Ok(None),
        }
    }

    #[uniffi::method]
    pub fn remove(&self) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        queue.remove()?;
        Ok(())
    }

    #[uniffi::method]
    pub fn remove_n(&self, n: u32) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        queue.remove_n(n as usize)?;
        Ok(())
    }

    #[uniffi::method]
    pub fn clear(&self) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        queue.clear()?;
        Ok(())
    }

    #[uniffi::method]
    pub fn is_empty(&self) -> Result<bool, QueueFileError> {
        let queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        Ok(queue.is_empty())
    }

    #[uniffi::method]
    pub fn size(&self) -> Result<u32, QueueFileError> {
        let queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        Ok(queue.size() as u32)
    }

    #[uniffi::method]
    pub fn file_len(&self) -> Result<u64, QueueFileError> {
        let queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        Ok(queue.file_len())
    }

    #[uniffi::method]
    pub fn used_bytes(&self) -> Result<u64, QueueFileError> {
        let queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        Ok(queue.used_bytes())
    }

    #[uniffi::method]
    pub fn get_all(&self) -> Result<Vec<Vec<u8>>, QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        let items: Vec<Vec<u8>> = queue.iter().map(|boxed| boxed.to_vec()).collect();
        Ok(items)
    }

    #[uniffi::method]
    pub fn sync_all(&self) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        queue.sync_all()?;
        Ok(())
    }

    #[uniffi::method]
    pub fn set_sync_writes(&self, value: bool) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        queue.set_sync_writes(value);
        Ok(())
    }

    #[uniffi::method]
    pub fn sync_writes(&self) -> Result<bool, QueueFileError> {
        let queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        Ok(queue.sync_writes())
    }

    #[uniffi::method]
    pub fn set_overwrite_on_remove(&self, value: bool) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        queue.set_overwrite_on_remove(value);
        Ok(())
    }

    #[uniffi::method]
    pub fn overwrite_on_remove(&self) -> Result<bool, QueueFileError> {
        let queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        Ok(queue.overwrite_on_remove())
    }

    #[uniffi::method]
    pub fn set_cache_offset_policy(&self, policy: OffsetCachePolicy) -> Result<(), QueueFileError> {
        let mut queue = self.inner.lock().map_err(|_| QueueFileError::LockError)?;
        match policy {
            OffsetCachePolicy::None => queue.set_cache_offset_policy(None),
            OffsetCachePolicy::Linear { offset } => {
                queue.set_cache_offset_policy(queue_file::OffsetCacheKind::Linear {
                    offset: offset as usize,
                })
            }
            OffsetCachePolicy::Quadratic => {
                queue.set_cache_offset_policy(queue_file::OffsetCacheKind::Quadratic)
            }
        }
        Ok(())
    }
}

uniffi::setup_scaffolding!();
