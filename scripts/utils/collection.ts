import * as fs from "fs";
import { COLLECTIONS_PATH } from "./constant";
import { CollectionInfo } from "./types";



export const getCollection = (): CollectionInfo => {
    const collection = JSON.parse(fs.readFileSync(COLLECTIONS_PATH, "utf8"));
    return collection;
}